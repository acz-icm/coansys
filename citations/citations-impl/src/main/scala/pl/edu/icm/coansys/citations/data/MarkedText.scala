/*
 * This file is part of CoAnSys project.
 * Copyright (c) 2012-2015 ICM-UW
 * 
 * CoAnSys is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.

 * CoAnSys is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Affero General Public License for more details.
 * 
 * You should have received a copy of the GNU Affero General Public License
 * along with CoAnSys. If not, see <http://www.gnu.org/licenses/>.
 */

package pl.edu.icm.coansys.citations.data

import org.apache.hadoop.io.{WritableComparator, BooleanWritable, Text, WritableComparable}
import java.io.{DataOutput, DataInput}
import org.apache.hadoop.mapreduce.Partitioner
import org.apache.hadoop.io.LongWritable.Comparator

/**
 * @author Mateusz Fedoryszak (m.fedoryszak@icm.edu.pl)
 */
class MarkedText(val marked: Boolean) extends WritableComparable[MarkedText]  {
  def this() = this(false)
  def this(text: String, marked: Boolean = false) = {
    this(marked)
    this.text.set(text)
  }

  val text = new Text
  val isMarked = new BooleanWritable(marked)

  def readFields(in: DataInput) {
    text.readFields(in)
    isMarked.readFields(in)
  }

  def write(out: DataOutput) {
    text.write(out)
    isMarked.write(out)
  }

  def compareTo(o: MarkedText) = {
    val textCompare = text.compareTo(o.text)
    if (textCompare == 0)
      -isMarked.compareTo(o.isMarked)
    else
      textCompare
  }

  override def hashCode() = text.hashCode() + 31 * isMarked.hashCode()

  override def equals(obj: scala.Any) = obj match {
    case o: MarkedText =>
      text.equals(o.text) && isMarked.equals(o.isMarked)
    case _ => false
  }

  override def toString = text.toString + (if (isMarked.get()) " *" else "")
}

class MarkedTextPartitioner extends Partitioner[MarkedText, Any] {
  def getPartition(key: MarkedText, value: Any, partitions: Int) =
    (key.text.hashCode() & Integer.MAX_VALUE) % partitions
}

class MarkedTextSortComparator extends WritableComparator(classOf[MarkedText], true) {
  override def compare(w1: WritableComparable[_], w2: WritableComparable[_]): Int = {
    val m1 = w1.asInstanceOf[MarkedText]
    val m2 = w2.asInstanceOf[MarkedText]

    m1.compareTo(m2)
  }
}

class MarkedTextGroupComparator extends WritableComparator(classOf[MarkedText], true) {
  override def compare(w1: WritableComparable[_], w2: WritableComparable[_]): Int = {
    val m1 = w1.asInstanceOf[MarkedText]
    val m2 = w2.asInstanceOf[MarkedText]

    m1.text.compareTo(m2.text)
  }
}
