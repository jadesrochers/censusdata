const fs = require('fs');
const os = require('os');
const filere = require('@jadesrochers/filereworker')
const R = require('ramda')
const fps = require('@jadesrochers/fpstreamline');
const streams = require('@jadesrochers/streams')
const datapulse = require('@jadesrochers/datapulse')
const mongosimple = require('@jadesrochers/mongosimple')
const csvtojson = require('csvtojson');
const yargs = require('yargs')

const splitTypes = (arg) => {
  if(typeof(arg) === 'boolean'){return arg;}
  return arg.split(',')
}

// if you don't use the variable directly, then it is assumed you are 
// probably calling various commands/modules and using that functionality  
// as opposed to needing to do anything directly with the arguments.  
const argv = yargs
  .help('h')
  .alias('h', 'help')
  .usage('Usage: $0 [options] sourcedata.csv')
  .option('db', {
    alias: 'd',
    describe: 'Destination database'
  })
  .option('collection', {
    alias: 'c',
    describe: 'Destination collection'
  })
  .option('vars', {
    alias: 'v',
    describe: 'List of comma separated variables to use'
  })
  .option('keyvars', {
    alias: 'e',
    default: 'GEO_ID,Area_name',
    describe: 'List of variables to use for checking whether row exists'
  })
  .option('mongoport', {
    alias: 'p',
    default: '27017',
    describe: 'Port to access mongodb at'
  })
  .option('dryrun', {
    alias: 'r',
    type: 'boolean',
    describe: 'Flag to specify a dry run that will not insert/update data'
  })
  .coerce('vars', splitTypes)
  .coerce('keyvars', splitTypes)
  .demandOption(['db', 'collection', 'vars'])
  .argv

console.log('Arguments obj: ', argv)


const mongouser=fs.readFileSync('./mongo_censususer.txt', "utf8")
const mongopass=fs.readFileSync('./mongo_censuspass.txt', "utf8")
console.log('mongouser, mongopass, mongoport: ', mongouser, mongopass, argv.mongoport)
var mongouseruri = encodeURIComponent(mongouser.replace(/(\r\n|\n|\r)/gm, ""));
var mongopassuri = encodeURIComponent(mongopass.replace(/(\r\n|\n|\r)/gm, ""));

// remember to use localhost instead of service name
urldb = `mongodb://${mongouseruri}:${mongopassuri}@localhost:${argv.mongoport}/admin?authMechanism=SCRAM-SHA-1&authSource=admin`
// let settings = { database: database, dburl: dburl }
// var db = await mongosimple.mongoMaker(settings);

const settings = { datapath: argv._[0],
include: argv.vars,
urldb: urldb,
collection: argv.collection, 
database: argv.db,
dataAccum: 100,
encoding: 'UTF-8'
}
console.log('settings: ',settings)

const nameIndex = {
  key: {GEO_ID: 1, 'Areaname':1 },
  name: 'namefind'
}
const geoidIndex = {
  key: {GEO_ID: 1},
  name: 'geoidfind'
}

const processFile = async (settings) => {
  try {
    const db = await mongosimple.mongoMaker(settings);
    await db.createIndexes(settings.collection)(nameIndex)
    await db.createIndexes(settings.collection)(geoidIndex)
    let insertfn = insertData(db, settings)
    let updatefn = updateData(db, settings)
    let insertHolder = datapulse.storeAndWrite(settings.dataAccum)(insertfn)
    let updateHolder = datapulse.storeAndWrite(settings.dataAccum)(updatefn)
    let sortfcn = sortRows(updateHolder, insertHolder, settings, db)

    let readstream = streams.fileStream(settings.datapath)
    let rowFormat = streams.transformStream(rowTransform)
    let excludeFields = streams.transformStream(selectData(settings.include))
    let pipeSortRows = streams.writeStream(sortfcn)
    let countLines = streams.countStream(100)(' Lines read from: ' + filere.getFileName(settings.datapath))
    let printLines = streams.writeStream(logrow)
    // variable that need setting for streams to work
    readstream 
      .pipe(csvtojson())
      .pipe(rowFormat)
      .pipe(excludeFields)
      .pipe(countLines)
      /* .pipe(printLines) */
      .pipe(pipeSortRows)
      .on('finish', async () => {
          await insertHolder.flush()
          await updateHolder.flush()
          await db.closeConnect()
          console.log('Read all of file: ',settings.datapath)
          process.exit(0)
        })

  }catch(err){
    console.log("Populating of Population database error: ",err)
  }
}

const sortRows = R.curry( async (updateHolder, insertHolder, settings, db, row ) => {
  const hasvars = checkVars(settings, row)
  const exists = await checkLocation(settings, db, row)
  const dupe = await checkExact(settings, db, row)
  if( ! exists | ! dupe ){
    console.log('exists, dupe and hasvars: ', exists,  dupe, hasvars); console.log('row: ', row)
  }
  if(exists && ! dupe && hasvars && ! argv.dryrun){
    await updateHolder.add(row)  
  }else if(! exists && hasvars && ! argv.dryrun){
    await insertHolder.add(row)
  }
})

const checkvals = (row) => {
  let checks = R.map((n) => { let a={}; a[n]=row[n]; return a; }, argv.keyvars )
  const rslt = R.mergeAll(checks)
  return rslt
}

const checkVars = R.curry((settings, row) => {
  /* let name = row.Area_name */
  const checkkeys = R.map((key) => (R.has(key, row) && ! R.isEmpty(row[key])), settings.include)
  /* console.log('checkkeys; has required keys with values: ', checkkeys) */
  const haskeys = R.all((n) => (n === true), checkkeys)
  /* console.log('haskeys: ', haskeys) */
  return haskeys
})

const checkLocation = R.curry(async (settings, db, row) => {
  /* let name = row.Area_name */
  const checkobj = checkvals(row)
  const exists = await db.checkExists(settings.collection)({ ...checkobj })
  return exists
})

const checkExact = R.curry(async (settings, db, row) => {
  const exact = await db.checkExists(settings.collection)({ ...row })
  return exact
})

const updateData = R.curry(async (db, settings, alldata) => {
   console.log('updating data')
   /* console.log('data to update: ', alldata) */
   // await R.map(updateRow(db, settings))(alldata)
   // Might need to do this if updates are not properly waited for
   await Promise.all(R.map(updateRow(db, settings))(alldata))
})

const insertData = R.curry(async (db, settings, alldata) => {
  console.log('inserting data')
  await db.insertMany(settings.collection)(alldata)
})

const updateRow = R.curry(async (db, settings, row) => {
  /* const query = { GEO_ID: datarow.GEO_ID, Area_name: datarow.Area_name } */
  const query = checkvals(row)
  const update = R.omit([ ...argv.keyvars ], row)
  await db.updateset(settings.collection)(query, update)
})

const bufferToJSON = R.pipe(
  R.toString,
  fps.toJSON,
)

const selectData = ( include ) => {
  return R.pipe(
    R.pick(include)
  )
}

const rowTransform = R.pipe(
  bufferToJSON,
  R.map(fps.strToNum),
)

const logrow = (row) => {
  console.log(row)
}

const runscript = async () => {
  await processFile(settings)
}

processFile(settings)
